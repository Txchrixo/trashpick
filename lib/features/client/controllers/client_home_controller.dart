import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/app_user.dart';
import '../../../models/trash_report.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/location_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';

class ClientHomeController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker _imagePicker = ImagePicker();

  final Rx<AppUser?> currentUser = Rx<AppUser?>(null);
  final Rx<TrashReport?> activeRequest = Rx<TrashReport?>(null);
  final RxBool isToggleOn = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploadingPhotos = false.obs;
  final RxString uploadProgress = ''.obs;
  final RxString statusMessage = 'Pas de demande active'.obs;
  final RxString notesSaveStatus = ''.obs;

  final TextEditingController notesController = TextEditingController();

  final mapController = MapController();
  final Rx<LatLng?> userLocation = Rx<LatLng?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _listenToActiveRequest();
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  /// Charge les données utilisateur
  Future<void> _loadUserData() async {
    final userId = _authService.userId;
    if (userId != null) {
      _firestoreService.listenToUser(userId).listen((user) {
        currentUser.value = user;
        if (user != null && user.latitude != null && user.longitude != null) {
          userLocation.value = LatLng(user.latitude!, user.longitude!);
          _moveCamera();
        }
      });
    }
  }

  /// Écoute la demande active du client en temps réel
  void _listenToActiveRequest() {
    final userId = _authService.userId;
    if (userId != null) {
      _firestoreService.listenToClientActiveRequest(userId).listen((request) {
        activeRequest.value = request;

        if (request != null) {
          // Il existe une demande non complétée
          isToggleOn.value = request.isActive;
          notesController.text = request.clientNotes ?? '';
          _updateStatusMessage(request);
        } else {
          // Aucune demande active
          isToggleOn.value = false;
          notesController.text = '';
          statusMessage.value = 'Pas de demande active';
        }

        print('🔔 Demande active: ${request?.id}, isActive=${request?.isActive}, status=${request?.status}');
      });
    }
  }

  /// Met à jour le message de statut
  void _updateStatusMessage(TrashReport request) {
    if (!request.isActive) {
      statusMessage.value = 'Demande en pause';
    } else {
      switch (request.status) {
        case TrashStatus.pending:
          statusMessage.value = 'En attente de récupération...';
          break;
        case TrashStatus.inTransit:
          statusMessage.value = 'Picker en route 🚚';
          break;
        case TrashStatus.completed:
          statusMessage.value = 'Récupéré ✓';
          break;
        case TrashStatus.cancelled:
          statusMessage.value = 'Annulé';
          break;
      }
    }
  }

  /// Gère le toggle de demande de récupération
  Future<void> togglePickupRequest() async {
    if (isLoading.value) return;

    // Inverser l'état du toggle
    final newToggleState = !isToggleOn.value;

    if (newToggleState) {
      // ACTIVATION du toggle
      await _activatePickupRequest();
    } else {
      // DÉSACTIVATION du toggle
      await _deactivatePickupRequest();
    }
  }

  /// Active la demande de récupération
  Future<void> _activatePickupRequest() async {
    isLoading.value = true;

    try {
      final user = currentUser.value;
      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non trouvé');
        return;
      }

      // Récupérer la position actuelle
      final position = await _locationService.getCurrentPosition();
      final lat = position?.latitude ?? user.latitude ?? 0.0;
      final lng = position?.longitude ?? user.longitude ?? 0.0;

      // Utiliser la nouvelle méthode intelligente
      final requestId = await _firestoreService.activatePickupRequest(
        clientId: user.id,
        latitude: lat,
        longitude: lng,
        quartier: user.quartier,
        clientNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        photosUrls: activeRequest.value?.photosUrls ?? [],
      );

      print('✅ Demande activée: $requestId');

      Get.snackbar(
        'Succès',
        activeRequest.value != null
            ? 'Demande réactivée'
            : 'Demande créée',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      print('❌ Erreur activation: $e');
      Get.snackbar('Erreur', e.toString());
      // Remettre le toggle à OFF en cas d'erreur
      isToggleOn.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Désactive la demande de récupération (toggle OFF)
  Future<void> _deactivatePickupRequest() async {
    isLoading.value = true;

    try {
      final request = activeRequest.value;
      if (request == null) {
        isToggleOn.value = false;
        return;
      }

      // Vérifier si la demande a déjà été complétée par un picker
      if (request.status == TrashStatus.completed) {
        isToggleOn.value = false;
        statusMessage.value = 'Récupéré ✓';
        return;
      }

      // Désactiver la demande (ne la supprime PAS, juste isActive = false)
      await _firestoreService.deactivatePickupRequest(request.id);

      print('⏸️ Demande désactivée (mise en pause)');

      Get.snackbar(
        'Info',
        'Demande mise en pause',
        backgroundColor: AppColors.info,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      print('❌ Erreur désactivation: $e');
      Get.snackbar('Erreur', e.toString());
      // Remettre le toggle à ON en cas d'erreur
      isToggleOn.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Met à jour les notes de la demande avec feedback visuel
  Future<void> updateNotes(String notes) async {
    final request = activeRequest.value;
    if (request != null && request.isActive) {
      try {
        notesSaveStatus.value = 'Sauvegarde...';

        await _firestoreService.updateTrashReport(request.id, {
          'clientNotes': notes.isEmpty ? null : notes,
        });

        notesSaveStatus.value = 'Sauvegardé ✓';

        // Effacer le message après 2 secondes
        Future.delayed(const Duration(seconds: 2), () {
          notesSaveStatus.value = '';
        });
      } catch (e) {
        notesSaveStatus.value = 'Erreur lors de la sauvegarde';
        Future.delayed(const Duration(seconds: 3), () {
          notesSaveStatus.value = '';
        });
      }
    }
  }

  /// Affiche le dialog pour choisir la source de l'image
  Future<void> pickAndUploadImages() async {
    if (activeRequest.value == null) {
      Get.snackbar('Erreur', 'Veuillez d\'abord activer la demande de récupération');
      return;
    }

    if (!activeRequest.value!.isActive) {
      Get.snackbar('Erreur', 'Veuillez réactiver votre demande pour ajouter des photos');
      return;
    }

    // Vérifier la limite de 3 photos
    final currentPhotosCount = activeRequest.value!.photosUrls.length;
    if (currentPhotosCount >= 3) {
      Get.snackbar(
        'Limite atteinte',
        'Vous avez déjà ajouté 3 photos (maximum)',
        backgroundColor: AppColors.info,
        colorText: AppColors.textWhite,
      );
      return;
    }

    // Afficher le dialog de choix
    await Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter une photo',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () {
                Get.back();
                _pickImageFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.secondary),
              title: const Text('Choisir de la galerie'),
              onTap: () {
                Get.back();
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
      isDismissible: true,
    );
  }

  /// Récupère et upload les images depuis la source choisie
  Future<void> _pickImageFromSource(ImageSource source) async {
    print('🔵 _pickImageFromSource démarré avec source: $source');

    try {
      final currentPhotosCount = activeRequest.value!.photosUrls.length;
      final remainingSlots = 3 - currentPhotosCount;

      List<XFile> images = [];

      if (source == ImageSource.camera) {
        // Camera: une seule photo à la fois
        print('📸 Ouverture de la caméra...');
        final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
        if (image != null) {
          images.add(image);
          print('✅ Photo prise: ${image.path}');
        } else {
          print('❌ Aucune photo prise (annulé)');
        }
      } else {
        // Galerie: multi-sélection possible
        print('🖼️ Ouverture de la galerie...');
        images = await _imagePicker.pickMultiImage();
        print('✅ ${images.length} image(s) sélectionnée(s)');
      }

      if (images.isEmpty) {
        print('⚠️ Aucune image sélectionnée, arrêt');
        return;
      }

      // Limiter le nombre de nouvelles photos
      final imagesToUpload = images.take(remainingSlots).toList();

      if (images.length > remainingSlots) {
        Get.snackbar(
          'Info',
          'Seulement $remainingSlots photo(s) seront ajoutée(s) (limite: 3 photos)',
          backgroundColor: AppColors.info,
          colorText: AppColors.textWhite,
        );
      }

      // Activer l'indicateur de chargement
      print('🔄 Activation de l\'indicateur de chargement...');
      isUploadingPhotos.value = true;
      uploadProgress.value = 'Préparation...';

      final reportId = activeRequest.value!.id;
      final userId = currentUser.value?.id;
      print('📋 Report ID: $reportId');
      print('👤 User ID: $userId');
      final List<String> newUrls = [];

      // Calculer l'index de départ (nombre de photos déjà uploadées + 1)
      final int startIndex = activeRequest.value!.photosUrls.length + 1;

      // Upload avec indicateur de progression
      print('🚀 Début de l\'upload de ${imagesToUpload.length} image(s)...');
      for (int i = 0; i < imagesToUpload.length; i++) {
        uploadProgress.value = 'Upload ${i + 1}/${imagesToUpload.length}...';
        final int imageNumber = startIndex + i;
        print('📤 Upload de l\'image #$imageNumber: ${imagesToUpload[i].name}');

        final url = await _cloudinaryService.uploadTrashImage(
          imagesToUpload[i],
          reportId,
          userId: userId,
          imageIndex: imageNumber,
        );
        if (url != null) {
          newUrls.add(url);
          print('✅ Image #$imageNumber uploadée avec succès: $url');
        } else {
          print('⚠️ Échec de l\'upload de l\'image #$imageNumber');
        }
      }

      print('📊 Total URLs obtenues: ${newUrls.length}');

      if (newUrls.isNotEmpty) {
        uploadProgress.value = 'Finalisation...';
        print('💾 Mise à jour de Firestore avec ${newUrls.length} nouvelle(s) URL(s)...');

        final currentPhotos = List<String>.from(activeRequest.value!.photosUrls);
        currentPhotos.addAll(newUrls);

        await _firestoreService.updateTrashReport(reportId, {
          'photosUrls': currentPhotos,
        });

        uploadProgress.value = '';
        print('✅ Upload terminé avec succès!');

        Get.snackbar(
          'Succès',
          '${newUrls.length} photo(s) ajoutée(s) ✓',
          backgroundColor: AppColors.success,
          colorText: AppColors.textWhite,
          duration: const Duration(seconds: 2),
        );
      } else {
        print('⚠️ Aucune URL obtenue après l\'upload');
      }
    } catch (e, stackTrace) {
      print('❌ ERREUR CRITIQUE lors de l\'upload:');
      print('❌ Message: $e');
      print('❌ Stack trace: $stackTrace');
      uploadProgress.value = '';
      Get.snackbar(
        'Erreur',
        'Impossible d\'ajouter la photo: ${e.toString()}',
        backgroundColor: AppColors.error,
        colorText: AppColors.textWhite,
      );
    } finally {
      print('🏁 Fin de _pickImageFromSource (finally block)');
      isUploadingPhotos.value = false;
      uploadProgress.value = '';
    }
  }

  /// Supprime une photo de la demande
  Future<void> removePhoto(int index) async {
    final request = activeRequest.value;
    if (request == null || !request.isActive) return;

    try {
      isLoading.value = true;

      final currentPhotos = List<String>.from(request.photosUrls);
      currentPhotos.removeAt(index);

      await _firestoreService.updateTrashReport(request.id, {
        'photosUrls': currentPhotos,
      });

      Get.snackbar(
        'Succès',
        'Photo supprimée',
        backgroundColor: AppColors.success,
        colorText: AppColors.textWhite,
      );
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Déplace la caméra sur la position de l'utilisateur
  void _moveCamera() {
    if (userLocation.value != null) {
      mapController.move(userLocation.value!, 15.0);
    }
  }

  void onMapCreated() {
    _moveCamera();
  }

  /// Génère les markers pour la carte Flutter Map
  List<Marker> getMarkers() {
    final markers = <Marker>[];

    if (userLocation.value != null) {
      markers.add(
        Marker(
          point: userLocation.value!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 40,
          ),
        ),
      );
    }

    return markers;
  }
}
