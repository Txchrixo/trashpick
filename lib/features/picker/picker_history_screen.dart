import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../models/trash_report.dart';
import 'controllers/picker_history_controller.dart';

class PickerHistoryScreen extends StatelessWidget {
  const PickerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PickerHistoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des collectes'),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active requests section
              if (controller.activeRequests.isNotEmpty) ...[
                Text(
                  'Collectes en cours',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.activeRequests
                    .map((request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRequestCard(request, controller),
                        )),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Completed requests section
              Text(
                'Collectes complétées',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Stats card
              _buildStatsCard(controller),
              const SizedBox(height: 16),

              // Completed requests list
              if (controller.completedRequests.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune collecte complétée',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: controller.completedRequests
                      .map((request) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRequestCard(request, controller),
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard(PickerHistoryController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.check_circle,
              value: controller.completedRequests.length.toString(),
              label: 'Complétées',
              color: AppColors.success,
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
            ),
            _buildStatItem(
              icon: Icons.pending_actions,
              value: controller.activeRequests.length.toString(),
              label: 'En cours',
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
      TrashReport request, PickerHistoryController controller) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isActive = request.status != TrashStatus.completed &&
        request.status != TrashStatus.cancelled;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Collecte #${request.id.substring(0, 8)}',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: controller.getStatusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    controller.getStatusText(request.status),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: controller.getStatusColor(request.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              text: dateFormat.format(request.createdAt),
            ),
            if (request.quartier != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.location_on,
                text: request.quartier!,
              ),
            ],
            if (!isActive && request.completedAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.check_circle,
                text: 'Complété le ${dateFormat.format(request.completedAt!)}',
                color: AppColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
