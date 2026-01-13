import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import 'controllers/picker_home_controller.dart';
import 'widgets/trash_list_item.dart';
import 'trash_detail_screen.dart';
import 'picker_history_screen.dart';

class PickerHomeScreen extends StatelessWidget {
  const PickerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PickerHomeController>();
    final AuthService authService = Get.find<AuthService>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/images/logo-trashpick-picker.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textWhite,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => _showProfileMenu(context, authService),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.textWhite,
            labelColor: AppColors.textWhite,
            unselectedLabelColor: AppColors.textWhite.withValues(alpha: 0.7),
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Liste'),
              Tab(icon: Icon(Icons.map), text: 'Carte'),
              Tab(icon: Icon(Icons.history), text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListTab(controller),
            _buildMapTab(controller),
            const PickerHistoryScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab(PickerHomeController controller) {
    return Column(
      children: [
        // Filter section
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
                child: Obx(() {
                  final filterValue = controller.quartierFilter.value;
                  return DropdownButtonFormField<String>(
                    value: filterValue.isEmpty ? null : filterValue,
                    decoration: InputDecoration(
                      labelText: 'Quartier',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tous les quartiers'),
                      ),
                      ...controller.availableQuartiers.map((quartier) {
                        return DropdownMenuItem<String>(
                          value: quartier,
                          child: Text(quartier),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      controller.setQuartierFilter(value);
                    },
                  );
                }),
              ),
              const SizedBox(width: 8),
              Obx(() {
                return controller.quartierFilter.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_all),
                        onPressed: controller.clearFilter,
                        tooltip: 'Effacer le filtre',
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
        // List section
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.trashReportsWithDistance.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 80,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.quartierFilter.value.isNotEmpty
                          ? 'Aucune demande dans ce quartier'
                          : 'Aucune demande en attente',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await controller.loadPendingTrashReports();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.trashReportsWithDistance.length,
                itemBuilder: (context, index) {
                  final item = controller.trashReportsWithDistance[index];
                  return TrashListItem(
                    report: item.report,
                    distance: item.distance,
                    onTap: () {
                      Get.to(() => TrashDetailScreen(
                            trashReport: item.report,
                            distance: item.distance,
                          ));
                    },
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMapTab(PickerHomeController controller) {
    return Obx(() {
      final location = controller.pickerLocation.value ?? const LatLng(3.8480, 11.5021);
      return Stack(
        children: [
          FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: location,
              initialZoom: 13.0,
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
                markers: controller.getMarkers((report) {
                  Get.to(() => TrashDetailScreen(trashReport: report));
                }),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Obx(() => Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${controller.pendingTrashReports.length} demande(s) en attente',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                  ),
                )),
          ),
        ],
      );
    });
  }

  void _showProfileMenu(BuildContext context, AuthService authService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person, color: AppColors.secondary),
                title: Text(
                  'Mon compte',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Get.back();
                  Get.toNamed('/picker-account');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Se déconnecter',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () async {
                  Get.back();
                  await authService.signOut();
                  Get.offAllNamed('/auth-choice');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
