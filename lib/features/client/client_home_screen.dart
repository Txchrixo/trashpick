import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/auth_service.dart';
import 'controllers/client_home_controller.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClientHomeController>();
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo-trashpick-client.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                _showProfileMenu(context, authService);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Obx(() {
              final center = controller.userLocation.value ?? const LatLng(3.8480, 11.5021);
              return FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 15.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onMapReady: () {
                    controller.onMapCreated();
                  },
                ),
                children: [
                  // OpenStreetMap tiles
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.trashpicker.app',
                    maxZoom: 19,
                    maxNativeZoom: 19,
                  ),
                  // Markers layer
                  MarkerLayer(
                    markers: controller.getMarkers(),
                  ),
                ],
              );
            }),
          ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demande de récupération',
                                    style: AppTextStyles.h4,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.statusMessage.value,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: controller.isToggleOn.value,
                              onChanged: controller.isLoading.value
                                  ? null
                                  : (_) => controller.togglePickupRequest(),
                              activeTrackColor: AppColors.primary,
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),
                    Obx(() => controller.isToggleOn.value
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Obx(() {
                                final photosCount = controller.activeRequest.value?.photosUrls.length ?? 0;
                                final canAddPhotos = photosCount < 3;
                                final isUploading = controller.isUploadingPhotos.value;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: controller.isLoading.value || !canAddPhotos || isUploading
                                          ? null
                                          : controller.pickAndUploadImages,
                                      icon: isUploading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.camera_alt),
                                      label: Text(
                                        isUploading
                                            ? controller.uploadProgress.value
                                            : canAddPhotos
                                                ? 'Ajouter photos ($photosCount/3)'
                                                : 'Maximum atteint (3/3)',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canAddPhotos
                                            ? AppColors.secondary
                                            : AppColors.divider,
                                        foregroundColor: AppColors.textWhite,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    if (isUploading)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: LinearProgressIndicator(
                                          backgroundColor: AppColors.divider,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),
                              if (controller.activeRequest.value?.photosUrls.isNotEmpty ?? false)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Photos (${controller.activeRequest.value!.photosUrls.length}/3)',
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: controller.activeRequest.value!.photosUrls.length,
                                        itemBuilder: (context, index) {
                                          final photoUrl = controller.activeRequest.value!.photosUrls[index];
                                          return Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            width: 100,
                                            child: Stack(
                                              children: [
                                                // Image avec preview cliquable
                                                GestureDetector(
                                                  onTap: () => _showImagePreview(context, photoUrl),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: AppColors.divider,
                                                        width: 2,
                                                      ),
                                                      image: DecorationImage(
                                                        image: NetworkImage(photoUrl),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Bouton supprimer
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () => _confirmDeletePhoto(context, controller, index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.error,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.close,
                                                        color: AppColors.textWhite,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Notes',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Obx(() {
                                        final status = controller.notesSaveStatus.value;
                                        if (status.isEmpty) return const SizedBox.shrink();

                                        return Row(
                                          children: [
                                            if (status == 'Sauvegarde...')
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                                                ),
                                              ),
                                            const SizedBox(width: 6),
                                            Text(
                                              status,
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: status == 'Sauvegardé ✓'
                                                    ? AppColors.success
                                                    : status == 'Sauvegarde...'
                                                        ? AppColors.info
                                                        : AppColors.error,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: controller.notesController,
                                    maxLines: 3,
                                    style: AppTextStyles.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: 'Notes importantes...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: AppColors.divider),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: AppColors.primary, width: 2),
                                      ),
                                    ),
                                    onChanged: controller.updateNotes,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              'Activez le toggle pour créer une demande',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                leading: Icon(Icons.person, color: AppColors.primary),
                title: Text(
                  'Mon compte',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Get.back();
                  Get.toNamed('/account');
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
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

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Image en grand
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Bouton fermer
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePhoto(BuildContext context, ClientHomeController controller, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Voulez-vous vraiment supprimer cette photo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.removePhoto(index);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
