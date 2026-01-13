import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import 'controllers/admin_picker_form_controller.dart';

class AdminPickerFormScreen extends StatelessWidget {
  const AdminPickerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminPickerFormController());
    final isEditing = controller.pickerToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier Picker' : 'Créer Picker'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing
                  ? 'Modifier les informations du picker'
                  : 'Créer un nouveau picker',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 24),

            // Nom complet
            TextFormField(
              controller: controller.nameController,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Téléphone
            TextFormField(
              controller: controller.phoneController,
              enabled: !isEditing,
              style: AppTextStyles.bodyMedium,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Téléphone (9 chiffres) *',
                prefixIcon: const Icon(Icons.phone),
                prefixText: '+237 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: isEditing,
                fillColor: isEditing
                    ? AppColors.divider.withValues(alpha: 0.1)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Mot de passe
            Obx(() => TextFormField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: isEditing
                        ? 'Nouveau mot de passe (optionnel)'
                        : 'Mot de passe *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
            const SizedBox(height: 16),

            // Quartier/Zone
            Obx(() => DropdownButtonFormField<String>(
              value: controller.selectedQuartier.value.isEmpty
                  ? null
                  : controller.selectedQuartier.value,
              decoration: InputDecoration(
                labelText: 'Zone/Quartier',
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
            )),
            const SizedBox(height: 16),

            // Adresse
            TextFormField(
              controller: controller.addressController,
              style: AppTextStyles.bodyMedium,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Adresse',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bouton Enregistrer
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.savePicker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
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
                          isEditing ? 'Mettre à jour' : 'Créer le picker',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textWhite,
                          ),
                        ),
                )),
          ],
        ),
      ),
    );
  }
}
