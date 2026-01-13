import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../models/trash_report.dart';
import '../controllers/picker_home_controller.dart';

class TrashListItem extends StatelessWidget {
  final TrashReport report;
  final double? distance;
  final VoidCallback onTap;

  const TrashListItem({
    super.key,
    required this.report,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PickerHomeController>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final foyer = controller.clientFoyerCache[report.clientId] ?? 'Foyer';
                      return Text(
                        'Poubelle $foyer #${report.id.substring(0, 6)}',
                        style: AppTextStyles.labelLarge,
                      );
                    }),
                    const SizedBox(height: 4),
                    if (report.quartier != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report.quartier!,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    if (distance != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.navigation_outlined,
                            size: 14,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            controller.formatDistance(distance!),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (report.photosUrls.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${report.photosUrls.length} photo(s)',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
