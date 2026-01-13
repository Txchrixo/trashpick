import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService extends GetxService {
  late CloudinaryPublic _cloudinary;

  @override
  void onInit() {
    super.onInit();
    _initializeCloudinary();
  }

  /// Initialise Cloudinary avec les credentials
  void _initializeCloudinary() {
    if (!CloudinaryConfig.isConfigured()) {
      print('⚠️ ${CloudinaryConfig.getConfigurationError()}');
      return;
    }

    _cloudinary = CloudinaryPublic(
      CloudinaryConfig.cloudName,
      CloudinaryConfig.uploadPreset,
      cache: false,
    );

    print('✅ CloudinaryService initialisé avec cloud: ${CloudinaryConfig.cloudName}');
  }

  /// Upload une image depuis XFile vers Cloudinary (compatible web + mobile)
  ///
  /// [xFile]: L'image à uploader (depuis image_picker)
  /// [trashReportId]: ID du rapport pour organiser les images
  /// [userId]: ID de l'utilisateur qui upload (optionnel)
  /// [imageIndex]: Numéro de l'image dans la séquence (optionnel, commence à 1)
  ///
  /// Retourne l'URL publique de l'image uploadée ou null en cas d'erreur
  Future<String?> uploadTrashImage(
    XFile xFile,
    String trashReportId, {
    String? userId,
    int? imageIndex,
  }) async {
    try {
      // Vérifier la configuration
      if (!CloudinaryConfig.isConfigured()) {
        print('❌ Configuration Cloudinary manquante');
        Get.snackbar(
          'Configuration manquante',
          CloudinaryConfig.getConfigurationError(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return null;
      }

      print('🔄 Upload Cloudinary - Fichier: ${xFile.name}');
      print('📋 Report ID: $trashReportId');
      if (userId != null) print('👤 User ID: $userId');

      // Lire les bytes de l'image (fonctionne sur web ET mobile)
      print('📖 Lecture des bytes depuis XFile...');
      final Uint8List fileBytes = await xFile.readAsBytes();
      print('📦 Taille du fichier: ${fileBytes.length} bytes');

      // Créer un nom de fichier avec pattern clair
      final String fileName = _generateFileName(xFile, userId, imageIndex);
      print('📝 Nom de fichier généré: $fileName');

      // Créer le dossier avec pattern: trash_reports/userId_reportId/
      final String folder = _generateFolderPath(trashReportId, userId);
      print('📁 Dossier: $folder');

      print('⏳ Upload vers Cloudinary...');

      // Upload vers Cloudinary
      final CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          fileBytes,
          identifier: fileName,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final String imageUrl = response.secureUrl;
      print('✅ Upload réussi! URL: $imageUrl');
      print('📊 Public ID: ${response.publicId}');

      return imageUrl;
    } catch (e, stackTrace) {
      print('❌ ERREUR CloudinaryService.uploadTrashImage:');
      print('❌ Message: $e');
      print('❌ Stack: $stackTrace');

      Get.snackbar(
        'Erreur Upload',
        'Impossible d\'uploader l\'image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return null;
    }
  }

  /// Upload plusieurs images en parallèle
  ///
  /// [xFiles]: Liste d'images à uploader
  /// [trashReportId]: ID du rapport
  ///
  /// Retourne la liste des URLs des images uploadées avec succès
  Future<List<String>> uploadMultipleImages(
    List<XFile> xFiles,
    String trashReportId,
  ) async {
    final List<String> uploadedUrls = [];

    for (final xFile in xFiles) {
      final url = await uploadTrashImage(xFile, trashReportId);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  /// Supprime une image de Cloudinary
  ///
  /// Note: Pour supprimer des images, vous devez:
  /// 1. Activer "Delete" dans votre Upload Preset Cloudinary
  /// 2. OU utiliser l'API Admin (nécessite API Key et Secret côté serveur)
  ///
  /// Pour des raisons de sécurité, la suppression directe depuis le client
  /// n'est pas recommandée. Il vaut mieux passer par un backend.
  Future<bool> deleteImage(String imageUrl) async {
    try {
      print('⚠️ Suppression d\'image Cloudinary non implémentée');
      print('ℹ️ Pour des raisons de sécurité, utilisez l\'API Admin côté serveur');

      // La suppression nécessite l'API Admin (API Key + Secret)
      // qui ne devrait PAS être exposée côté client
      // Implémentez cette fonctionnalité dans votre backend si nécessaire

      return false;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Génère un nom de fichier avec pattern lisible
  ///
  /// Format: YYYYMMDD_HHMMSS_userId_index.extension
  /// Exemple: 20251229_143055_client_abc123_1.jpg
  String _generateFileName(XFile xFile, String? userId, int? imageIndex) {
    final DateTime now = DateTime.now();

    // Format date: YYYYMMDD
    final String dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Format heure: HHMMSS
    final String timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    // Récupérer l'extension du fichier
    final String extension = xFile.name.split('.').last.toLowerCase();

    // Construire le nom du fichier
    final List<String> parts = [dateStr, timeStr];

    if (userId != null && userId.isNotEmpty) {
      // Nettoyer le userId (enlever caractères spéciaux)
      final cleanUserId = userId.replaceAll(RegExp(r'[^\w\-]'), '');
      parts.add(cleanUserId);
    }

    if (imageIndex != null) {
      parts.add(imageIndex.toString());
    }

    return '${parts.join('_')}.$extension';
  }

  /// Génère le chemin du dossier
  ///
  /// Format: trash_reports/userId_reportId
  /// Exemple: trash_reports/client_abc123_report_def456
  String _generateFolderPath(String trashReportId, String? userId) {
    final String baseFolder = CloudinaryConfig.uploadFolder;

    if (userId != null && userId.isNotEmpty) {
      // Nettoyer les IDs
      final cleanUserId = userId.replaceAll(RegExp(r'[^\w\-]'), '');
      final cleanReportId = trashReportId.replaceAll(RegExp(r'[^\w\-]'), '');

      // Format: trash_reports/userId_reportId
      return '$baseFolder/${cleanUserId}_$cleanReportId';
    }

    // Fallback si pas de userId: trash_reports/reportId
    return '$baseFolder/$trashReportId';
  }

  /// Récupère une URL d'image optimisée avec transformations Cloudinary
  ///
  /// [publicId]: Le public ID de l'image sur Cloudinary
  /// [width]: Largeur souhaitée (optionnel)
  /// [height]: Hauteur souhaitée (optionnel)
  /// [quality]: Qualité de l'image (auto, best, good, low)
  ///
  /// Exemple: getOptimizedUrl('trash_reports/abc123/image.jpg', width: 300, quality: 'auto')
  String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
    String quality = 'auto',
  }) {
    final transformations = <String>[];

    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_auto'); // Format automatique (WebP si supporté)

    final transformStr = transformations.join(',');

    return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$transformStr/$publicId';
  }
}
