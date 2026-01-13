# 📁 Pattern de nommage Cloudinary - TrashPicker

## 🎯 Objectif

Avoir une structure **claire et lisible** pour identifier facilement :
- ✅ À quel **utilisateur** appartient l'image
- ✅ À quel **trash report** elle est liée
- ✅ **Quand** elle a été uploadée
- ✅ L'**ordre** des images dans la séquence

---

## 📂 Structure des dossiers

### **Format**
```
trash_reports/{userId}_{reportId}/
```

### **Exemple**
```
cloudinary.com/dhcpkhuao/
└── trash_reports/
    ├── client_abc123_report_def456/
    ├── client_xyz789_report_ghi012/
    └── picker_mno345_report_pqr678/
```

### **Avantages**
- 🔍 **Recherche facile** : Trouver toutes les images d'un user ou d'un report
- 📊 **Organisation** : Un dossier par report
- 🔒 **Séparation** : Chaque report est isolé

---

## 📝 Pattern des noms de fichiers

### **Format**
```
{YYYYMMDD}_{HHMMSS}_{userId}_{imageIndex}.{extension}
```

### **Exemples**
```
20251229_143055_client_abc123_1.jpg
20251229_143102_client_abc123_2.jpg
20251229_153045_picker_xyz789_1.png
```

### **Décomposition**

| Partie | Exemple | Description |
|--------|---------|-------------|
| `YYYYMMDD` | `20251229` | Date d'upload (29 déc 2025) |
| `HHMMSS` | `143055` | Heure d'upload (14:30:55) |
| `userId` | `client_abc123` | ID de l'utilisateur |
| `imageIndex` | `1`, `2`, `3` | Numéro de l'image dans la séquence |
| `extension` | `jpg`, `png` | Format de l'image |

---

## 🔍 Exemples concrets

### **Scénario 1 : Client upload 3 photos**

**Contexte** :
- Client ID : `client_abc123`
- Report ID : `report_def456`
- Date : 29 décembre 2025, 14:30

**Résultat** :
```
trash_reports/client_abc123_report_def456/
├── 20251229_143055_client_abc123_1.jpg  ← 1ère photo (14:30:55)
├── 20251229_143102_client_abc123_2.jpg  ← 2ème photo (14:31:02)
└── 20251229_143108_client_abc123_3.jpg  ← 3ème photo (14:31:08)
```

**Ce que tu peux voir** :
- ✅ Toutes les photos appartiennent au client `abc123`
- ✅ Elles concernent le report `def456`
- ✅ Uploadées le 29/12/2025 vers 14h30
- ✅ Ordre chronologique : 1 → 2 → 3

---

### **Scénario 2 : Picker upload photo de ramassage**

**Contexte** :
- Picker ID : `picker_xyz789`
- Report ID : `report_ghi012`
- Date : 30 décembre 2025, 09:15

**Résultat** :
```
trash_reports/picker_xyz789_report_ghi012/
└── 20251230_091530_picker_xyz789_1.jpg
```

**Ce que tu peux voir** :
- ✅ Photo appartient au picker `xyz789`
- ✅ Concerne le report `ghi012`
- ✅ Uploadée le 30/12/2025 à 09:15:30
- ✅ C'est la 1ère (et seule) photo

---

### **Scénario 3 : Client ajoute photos plus tard**

**Contexte** :
- Client a déjà uploadé 2 photos
- Il en ajoute 1 autre quelques minutes plus tard

**Résultat** :
```
trash_reports/client_abc123_report_def456/
├── 20251229_143055_client_abc123_1.jpg  ← Upload 1
├── 20251229_143102_client_abc123_2.jpg  ← Upload 1
└── 20251229_144520_client_abc123_3.jpg  ← Upload 2 (ajouté plus tard)
```

**Ce que tu peux voir** :
- ✅ Les 2 premières ont le même timestamp (~14:30)
- ✅ La 3ème a un timestamp différent (~14:45)
- ✅ Mais l'index continue : 1, 2, 3 (pas de doublon)

---

## 🛠️ Implémentation technique

### **CloudinaryService - Génération du nom**

```dart
// Fichier: lib/services/cloudinary_service.dart

String _generateFileName(XFile xFile, String? userId, int? imageIndex) {
  final DateTime now = DateTime.now();

  // Date: YYYYMMDD
  final String dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

  // Heure: HHMMSS
  final String timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

  // Extension
  final String extension = xFile.name.split('.').last.toLowerCase();

  // Construction
  final List<String> parts = [dateStr, timeStr];

  if (userId != null) {
    final cleanUserId = userId.replaceAll(RegExp(r'[^\w\-]'), '');
    parts.add(cleanUserId);
  }

  if (imageIndex != null) {
    parts.add(imageIndex.toString());
  }

  return '${parts.join('_')}.$extension';
}
```

### **CloudinaryService - Génération du dossier**

```dart
String _generateFolderPath(String trashReportId, String? userId) {
  final String baseFolder = CloudinaryConfig.uploadFolder; // "trash_reports"

  if (userId != null && userId.isNotEmpty) {
    final cleanUserId = userId.replaceAll(RegExp(r'[^\w\-]'), '');
    final cleanReportId = trashReportId.replaceAll(RegExp(r'[^\w\-]'), '');

    // Format: trash_reports/userId_reportId
    return '$baseFolder/${cleanUserId}_$cleanReportId';
  }

  // Fallback sans userId
  return '$baseFolder/$trashReportId';
}
```

### **Controller - Appel avec userId et index**

```dart
// Fichier: lib/features/client/controllers/client_home_controller.dart

final reportId = activeRequest.value!.id;
final userId = currentUser.value?.id;

// Index = nombre de photos existantes + 1
final int startIndex = activeRequest.value!.photosUrls.length + 1;

for (int i = 0; i < imagesToUpload.length; i++) {
  final int imageNumber = startIndex + i;

  final url = await _cloudinaryService.uploadTrashImage(
    imagesToUpload[i],
    reportId,
    userId: userId,        // ← Passe le user ID
    imageIndex: imageNumber, // ← Passe l'index
  );
}
```

---

## 🔎 Recherche et filtrage

### **Dans Cloudinary Media Library**

Tu peux facilement chercher :

#### **Toutes les images d'un user**
```
Recherche: client_abc123
```

#### **Toutes les images d'un report**
```
Recherche: report_def456
```

#### **Images uploadées un jour précis**
```
Recherche: 20251229
```

#### **Toutes les images d'un dossier**
```
Filtre: trash_reports/client_abc123_report_def456/
```

---

## 📊 Avantages du pattern

| Avantage | Description |
|----------|-------------|
| 🔍 **Traçabilité** | On sait exactement qui a uploadé quoi et quand |
| 📅 **Chronologie** | Le timestamp montre l'ordre temporel |
| 🔢 **Séquence** | L'index montre l'ordre intentionnel (1, 2, 3) |
| 🗂️ **Organisation** | Un dossier par report, facile à naviguer |
| 🔎 **Recherche** | Recherche par user, report, ou date |
| 🔒 **Sécurité** | Séparation claire entre les reports |
| 📈 **Analyse** | Facile de compter combien de photos par report/user |

---

## 🎨 Format des URLs finales

### **URL publique Cloudinary**
```
https://res.cloudinary.com/dhcpkhuao/image/upload/trash_reports/client_abc123_report_def456/20251229_143055_client_abc123_1.jpg
```

### **URL optimisée (avec transformations)**
```
https://res.cloudinary.com/dhcpkhuao/image/upload/w_300,q_auto,f_auto/trash_reports/client_abc123_report_def456/20251229_143055_client_abc123_1.jpg
```

**Transformations appliquées** :
- `w_300` : Largeur 300px
- `q_auto` : Qualité automatique
- `f_auto` : Format auto (WebP si supporté)

---

## ✅ Checklist de vérification

Avant de lancer l'app, vérifie que :

- [ ] Tu as créé l'Upload Preset `trashpicker_preset` dans Cloudinary
- [ ] Le preset est en mode **"Unsigned"**
- [ ] Le fichier `cloudinary_config.dart` contient :
  - [ ] `cloudName = 'dhcpkhuao'`
  - [ ] `uploadPreset = 'trashpicker_preset'`
- [ ] Les méthodes `_generateFileName` et `_generateFolderPath` sont présentes dans `cloudinary_service.dart`
- [ ] Le controller passe bien `userId` et `imageIndex` lors de l'upload

---

## 🧪 Test du pattern

Après avoir uploadé des images, va dans [Cloudinary Media Library](https://console.cloudinary.com/console/media_library) et vérifie :

1. ✅ Les dossiers suivent le pattern `trash_reports/userId_reportId/`
2. ✅ Les noms de fichiers suivent le pattern `YYYYMMDD_HHMMSS_userId_index.ext`
3. ✅ Les index sont corrects (1, 2, 3)
4. ✅ Les timestamps reflètent l'heure d'upload

---

**Date** : 2025-12-29
**Version** : 2.0 (avec pattern de nommage structuré)
**Status** : ✅ Implémenté et prêt
