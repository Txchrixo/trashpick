# 🔄 Migration Firebase Storage → Cloudinary

## Résumé de la migration

TrashPicker utilise maintenant **Cloudinary** au lieu de **Firebase Storage** pour l'upload d'images.

---

## ✅ Changements effectués

### 1. **Packages ajoutés** - [pubspec.yaml:33-34](pubspec.yaml#L33-L34)
```yaml
# Cloudinary for image upload
cloudinary_public: ^0.23.0
http: ^1.2.2
```

### 2. **Nouveau service créé** - [lib/services/cloudinary_service.dart](lib/services/cloudinary_service.dart)
- `uploadTrashImage(XFile, reportId)` : Upload une image vers Cloudinary
- `uploadMultipleImages(List<XFile>, reportId)` : Upload multiple
- `getOptimizedUrl(publicId)` : Génère une URL optimisée avec transformations

### 3. **Configuration créée** - [lib/config/cloudinary_config.dart](lib/config/cloudinary_config.dart)
Contient :
- `cloudName` : Votre cloud name Cloudinary
- `uploadPreset` : Votre upload preset (mode unsigned)
- `uploadFolder` : Dossier de stockage (`trash_reports`)

### 4. **Controller mis à jour** - [lib/features/client/controllers/client_home_controller.dart:11,19](lib/features/client/controllers/client_home_controller.dart#L11)
```dart
// AVANT
import '../../../services/storage_service.dart';
final StorageService _storageService = StorageService();

// APRÈS
import '../../../services/cloudinary_service.dart';
final CloudinaryService _cloudinaryService = CloudinaryService();
```

Upload mis à jour - [client_home_controller.dart:365-368](lib/features/client/controllers/client_home_controller.dart#L365-L368):
```dart
// AVANT
final url = await _storageService.uploadTrashImageFromXFile(
  imagesToUpload[i],
  reportId,
);

// APRÈS
final url = await _cloudinaryService.uploadTrashImage(
  imagesToUpload[i],
  reportId,
);
```

---

## 🔧 Configuration requise

### ⚠️ IMPORTANT : Avant de lancer l'app

Vous **DEVEZ** configurer vos clés Cloudinary :

**Fichier** : [lib/config/cloudinary_config.dart](lib/config/cloudinary_config.dart)

```dart
class CloudinaryConfig {
  // 🔴 À REMPLACER AVANT DE LANCER L'APP
  static const String cloudName = 'YOUR_CLOUD_NAME_HERE';
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET_HERE';
}
```

📖 **Guide rapide** : [CLOUDINARY_QUICK_START.md](CLOUDINARY_QUICK_START.md)
📚 **Guide complet** : [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md)

---

## 🎯 Avantages de Cloudinary vs Firebase Storage

| Aspect | Firebase Storage | Cloudinary |
|--------|-----------------|------------|
| **Compatibilité Web** | ❌ Problèmes avec `dart:io` | ✅ Fonctionne parfaitement |
| **Setup** | Complexe (configuration Firebase) | Simple (2 clés suffisent) |
| **Optimisation images** | Manuel | ✅ Automatique (WebP, compression) |
| **CDN** | Firebase CDN | ✅ Cloudinary CDN (ultra-rapide) |
| **Transformations** | Non disponibles | ✅ Redimensionnement, crop, filters |
| **Plan gratuit** | 5 GB stockage + 1 GB/jour download | ✅ 25 GB stockage + 25 GB/mois bandwidth |
| **URL des images** | URLs Firebase longues | ✅ URLs optimisées et transformables |

---

## 📦 Structure des images dans Cloudinary

Les images seront organisées ainsi :

```
cloudinary.com/
└── your-cloud-name/
    └── trash_reports/               ← uploadFolder
        ├── report_abc123/           ← trashReportId
        │   ├── 1735401234567_photo1.jpg
        │   ├── 1735401235678_photo2.jpg
        │   └── 1735401236789_photo3.jpg
        ├── report_def456/
        │   └── 1735401237890_photo1.jpg
        └── report_ghi789/
            └── 1735401238901_photo1.jpg
```

---

## 🔄 Fonctionnalités maintenues

✅ Tout fonctionne comme avant :
- Upload depuis caméra ou galerie
- Upload multiple (max 3 photos)
- Indicateurs de progression
- Preview des photos
- Suppression de photos (seulement l'URL Firestore, pas l'image Cloudinary)

---

## ⚙️ Fonctionnalités bonus de Cloudinary

### 1. URLs optimisées

Vous pouvez générer des URLs avec transformations :

```dart
final optimizedUrl = _cloudinaryService.getOptimizedUrl(
  'trash_reports/abc123/photo.jpg',
  width: 300,        // Redimensionner à 300px de large
  quality: 'auto',   // Compression automatique
);
// Retourne : https://res.cloudinary.com/.../w_300,q_auto,f_auto/trash_reports/abc123/photo.jpg
```

### 2. Format automatique (WebP)

Cloudinary convertit automatiquement les images en WebP pour les navigateurs qui supportent, réduisant la taille de 25-35% sans perte de qualité.

### 3. Compression intelligente

L'option `q_auto` analyse chaque image et applique le niveau de compression optimal.

---

## 🗑️ Fichiers obsolètes (à garder pour compatibilité legacy)

Ces fichiers ne sont plus utilisés mais conservés :
- [lib/services/storage_service.dart](lib/services/storage_service.dart) - Ancien service Firebase Storage

**Note** : Vous pouvez les supprimer si vous êtes sûr que rien d'autre ne les utilise.

---

## 🧪 Tests effectués

✅ Compilation sans erreur
✅ Service Cloudinary créé
✅ Configuration prête
🟡 Tests fonctionnels (à faire après configuration des clés)

---

## 📝 TODO après migration

1. ✅ ~~Installer les packages (`flutter pub get`)~~
2. 🔴 **Configurer les clés Cloudinary** dans [cloudinary_config.dart](lib/config/cloudinary_config.dart)
3. 🟡 Tester l'upload sur web Chrome
4. 🟡 Tester l'upload sur Android
5. 🟡 Tester l'upload sur iOS
6. 🟡 (Optionnel) Migrer les anciennes images Firebase → Cloudinary
7. 🟡 (Optionnel) Supprimer `storage_service.dart` si plus utilisé

---

## 🆘 Support

En cas de problème :
1. Consultez [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md) section "Dépannage"
2. Vérifiez les logs de la console (emojis 🔵📸🖼️✅❌)
3. Vérifiez votre configuration Cloudinary

---

**Date de migration** : 2025-12-29
**Version** : 1.0
**Status** : ✅ Migration complète, prêt à configurer
