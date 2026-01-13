import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/trash_report.dart';
import 'controllers/admin_client_history_controller.dart';

class AdminClientHistoryScreen extends StatelessWidget {
  const AdminClientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminClientHistoryController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.client.value != null
                  ? 'Historique - ${controller.client.value!.name}'
                  : 'Historique Client',
            )),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.client.value == null) {
          return const Center(child: Text('Client introuvable'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active request section
            if (controller.activeRequest != null) ...[
              Text(
                'Demande active',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildRequestCard(controller.activeRequest!, controller),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Date filters section
            Text(
              'Historique des demandes complétées',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDateFilters(controller, context),
            const SizedBox(height: 16),

            // Completed requests list
            Obx(() {
              final completedRequests = controller.filteredCompletedRequests;

              if (completedRequests.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aucune demande complétée',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: completedRequests
                    .map((request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRequestCard(request, controller),
                        ))
                    .toList(),
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildDateFilters(
      AdminClientHistoryController controller, BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrer par date',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Quick date filter dropdown
            Obx(() => DropdownButtonFormField<QuickDateFilter>(
                  value: controller.quickDateFilter.value,
                  decoration: const InputDecoration(
                    labelText: 'Filtre rapide',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: QuickDateFilter.values
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(controller.getQuickFilterLabel(filter)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.setQuickDateFilter(value);
                    }
                  },
                )),
            const SizedBox(height: 16),

            // Custom date range (only visible when "Toutes les dates" is selected)
            Obx(() {
              if (controller.quickDateFilter.value != QuickDateFilter.all) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ou sélectionner une période personnalisée',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Start date picker
                      Expanded(
                        child: Obx(() => InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: controller.startDate.value ??
                                DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            controller.setStartDate(picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date début',
                            border: const OutlineInputBorder(),
                            suffixIcon: controller.startDate.value != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        controller.setStartDate(null),
                                  )
                                : const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            controller.startDate.value != null
                                ? dateFormat.format(controller.startDate.value!)
                                : 'Sélectionner',
                            style: controller.startDate.value != null
                                ? AppTextStyles.bodyMedium
                                : AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                        ),
                      )),
                ),
                const SizedBox(width: 12),
                // End date picker
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                controller.endDate.value ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            controller.setEndDate(picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date fin',
                            border: const OutlineInputBorder(),
                            suffixIcon: controller.endDate.value != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () => controller.setEndDate(null),
                                  )
                                : const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            controller.endDate.value != null
                                ? dateFormat.format(controller.endDate.value!)
                                : 'Sélectionner',
                            style: controller.endDate.value != null
                                ? AppTextStyles.bodyMedium
                                : AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                        ),
                      )),
                ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),

            // Clear filters button
            Obx(() {
              final hasFilters = controller.quickDateFilter.value !=
                      QuickDateFilter.all ||
                  controller.startDate.value != null ||
                  controller.endDate.value != null;
              return hasFilters
                  ? SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: controller.clearDateFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Effacer les filtres'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
      TrashReport request, AdminClientHistoryController controller) {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.getStatusText(request.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!request.isActive && request.status != TrashStatus.completed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Désactivé',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Request details
            _buildDetailRow(
              Icons.calendar_today,
              'Créé le',
              dateFormat.format(request.createdAt),
            ),
            const SizedBox(height: 8),
            if (request.completedAt != null) ...[
              _buildDetailRow(
                Icons.check_circle,
                'Complété le',
                dateFormat.format(request.completedAt!),
              ),
              const SizedBox(height: 8),
            ],
            if (request.quartier != null) ...[
              _buildDetailRow(
                Icons.location_on,
                'Quartier',
                request.quartier!,
              ),
              const SizedBox(height: 8),
            ],
            _buildDetailRow(
              Icons.category,
              'Catégorie',
              _getWasteCategoryText(request.wasteCategory),
            ),
            if (request.clientNotes != null &&
                request.clientNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.clientNotes!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (request.rating != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 20,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Évaluation: ${request.rating!.toStringAsFixed(1)}/5',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getWasteCategoryText(WasteCategory category) {
    switch (category) {
      case WasteCategory.organic:
        return 'Organique';
      case WasteCategory.recyclable:
        return 'Recyclable';
      case WasteCategory.general:
        return 'Général';
      case WasteCategory.hazardous:
        return 'Dangereux';
    }
  }
}
