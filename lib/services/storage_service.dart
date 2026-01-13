import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService extends GetxService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload une image depuis XFile (compatible web + mobile)
  Future<String?> uploadTrashImageFromXFile(
    XFile xFile,
    String trashReportId,
  ) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
      final String path = 'trash_reports/$trashReportId/$fileName';

      final Reference ref = _storage.ref().child(path);

      print('🔄 Upload Firebase Storage - Path: $path');

      // Sur web ET mobile, on utilise readAsBytes de XFile
      print('📖 Lecture des bytes depuis XFile...');
      final Uint8List fileBytes = await xFile.readAsBytes();
      print('📦 Taille du fichier: ${fileBytes.length} bytes');

      print('⏳ Upload vers Firebase Storage...');
      final UploadTask uploadTask = ref.putData(fileBytes);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload réussi! URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ ERREUR StorageService.uploadTrashImageFromXFile:');
      print('❌ Message: $e');
      print('❌ Stack: $stackTrace');
      Get.snackbar(
        'Erreur Upload',
        'Échec de l\'upload: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Upload une image depuis File (pour compatibilité legacy, mobile uniquement)
  Future<String?> uploadTrashImage(File imageFile, String trashReportId) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final String path = 'trash_reports/$trashReportId/$fileName';

      final Reference ref = _storage.ref().child(path);

      print('🔄 Upload Firebase Storage - Path: $path');

      UploadTask uploadTask;

      if (kIsWeb) {
        // Sur web, lire les bytes du fichier
        print('🌐 Mode WEB détecté, lecture des bytes...');
        final Uint8List fileBytes = await imageFile.readAsBytes();
        print('📦 Taille du fichier: ${fileBytes.length} bytes');
        uploadTask = ref.putData(fileBytes);
      } else {
        // Sur mobile, utiliser putFile
        print('📱 Mode MOBILE détecté, upload du fichier...');
        uploadTask = ref.putFile(imageFile);
      }

      print('⏳ Attente de la fin de l\'upload...');
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload réussi! URL: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      print('❌ ERREUR StorageService.uploadTrashImage:');
      print('❌ Message: $e');
      print('❌ Stack: $stackTrace');
      Get.snackbar(
        'Erreur Upload',
        'Échec de l\'upload: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<List<String>> uploadMultipleTrashImages(
    List<File> imageFiles,
    String trashReportId,
  ) async {
    final List<String> uploadedUrls = [];

    for (final file in imageFiles) {
      final url = await uploadTrashImage(file, trashReportId);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
