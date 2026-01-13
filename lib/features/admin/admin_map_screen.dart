import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import 'controllers/admin_map_controller.dart';

class AdminMapScreen extends StatelessWidget {
  const AdminMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminMapController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: const LatLng(3.8480, 11.5021), // Yaoundé
              initialZoom: 12.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapReady: () {
                controller.onMapCreated();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trashpicker.app',
                maxZoom: 19,
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: controller.markers,
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Carte globale',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildLegendItem(
                          'Pickers actifs',
                          AppColors.info,
                          controller.activePickers.length,
                        ),
                        const SizedBox(width: 16),
                        _buildLegendItem(
                          'Demandes',
                          AppColors.error,
                          controller.activeRequests.length,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
