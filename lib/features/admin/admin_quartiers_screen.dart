import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/quartier.dart';
import 'controllers/admin_quartiers_controller.dart';

class AdminQuartiersScreen extends StatelessWidget {
  const AdminQuartiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminQuartiersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Quartiers'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Add quartier section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.quartierNameController,
                      decoration: InputDecoration(
                        hintText: 'Nom du quartier',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => controller.addQuartier(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: controller.addQuartier,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quartiers list
            Expanded(
              child: Obx(() {
                if (controller.quartiers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun quartier',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez le premier quartier',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshQuartiers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.quartiers.length,
                    itemBuilder: (context, index) {
                      final quartier = controller.quartiers[index];
                      return _buildQuartierCard(quartier, controller);
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildQuartierCard(
      Quartier quartier, AdminQuartiersController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: quartier.isActive
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.textSecondary.withValues(alpha: 0.2),
          child: Icon(
            Icons.location_on,
            color: quartier.isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          quartier.name,
          style: AppTextStyles.labelLarge.copyWith(
            color: quartier.isActive
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quartier.clientCount} client(s)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.local_shipping,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quartier.pickerCount} picker(s)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!quartier.isActive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Désactivé',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              controller.showEditDialog(quartier);
            } else if (value == 'toggle') {
              controller.toggleQuartierStatus(quartier);
            } else if (value == 'delete') {
              controller.showDeleteConfirmation(quartier);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    quartier.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(quartier.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: quartier.userCount == 0,
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    size: 20,
                    color: quartier.userCount == 0
                        ? AppColors.error
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Supprimer',
                    style: TextStyle(
                      color: quartier.userCount == 0
                          ? AppColors.error
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
