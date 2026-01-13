/// Configuration Cloudinary
///
/// IMPORTANT: Ce fichier contient les clés API Cloudinary.
/// Pour des raisons de sécurité, ces valeurs devraient être stockées dans des variables d'environnement
/// ou un fichier .env en production.
class CloudinaryConfig {
  /// ⚠️ REMPLACER CETTE VALEUR PAR VOTRE CLOUD NAME CLOUDINARY
  ///
  /// Pour trouver votre Cloud Name:
  /// 1. Connectez-vous à https://cloudinary.com/
  /// 2. Allez dans Dashboard
  /// 3. Copiez la valeur "Cloud Name" affichée en haut
  ///
  /// Exemple: 'mon-cloud-name'
  static const String cloudName = 'dhcpkhuao';

  /// ⚠️ REMPLACER CETTE VALEUR PAR VOTRE UPLOAD PRESET CLOUDINARY
  ///
  /// Pour créer un Upload Preset:
  /// 1. Connectez-vous à https://cloudinary.com/
  /// 2. Allez dans Settings > Upload
  /// 3. Scrollez jusqu'à "Upload presets"
  /// 4. Cliquez sur "Add upload preset"
  /// 5. Configurez:
  ///    - Signing Mode: "Unsigned" (pour permettre l'upload depuis le client)
  ///    - Folder: "trash_reports" (optionnel, pour organiser vos images)
  ///    - Upload preset name: "trashpicker_preset" (ou le nom de votre choix)
  /// 6. Sauvegardez et copiez le nom du preset
  ///
  /// Exemple: 'trashpicker_preset'
  static const String uploadPreset = 'trashpicker_preset';

  /// Dossier où les images seront stockées dans Cloudinary
  /// Vous pouvez changer cette valeur selon vos besoins
  static const String uploadFolder = 'trash_reports';

  /// Vérifier si la configuration est valide
  static bool isConfigured() {
    return cloudName != 'YOUR_CLOUD_NAME_HERE' &&
        uploadPreset != 'YOUR_UPLOAD_PRESET_HERE' &&
        cloudName.isNotEmpty &&
        uploadPreset.isNotEmpty;
  }

  /// Message d'erreur si la configuration n'est pas complète
  static String getConfigurationError() {
    if (!isConfigured()) {
      return '''
🔴 Configuration Cloudinary manquante!

Veuillez configurer vos clés Cloudinary dans le fichier:
lib/config/cloudinary_config.dart

Instructions:
1. Cloud Name: Remplacer 'YOUR_CLOUD_NAME_HERE' par votre cloud name
2. Upload Preset: Remplacer 'YOUR_UPLOAD_PRESET_HERE' par votre upload preset

Pour obtenir ces valeurs, consultez: https://cloudinary.com/console
      ''';
    }
    return '';
  }
}
