# 🚀 Cloudinary - Configuration Rapide (5 minutes)

## 📍 Où placer vos clés API Cloudinary

**Fichier à modifier** : [`lib/config/cloudinary_config.dart`](lib/config/cloudinary_config.dart)

```dart
class CloudinaryConfig {
  // 1️⃣ REMPLACER PAR VOTRE CLOUD NAME
  static const String cloudName = 'YOUR_CLOUD_NAME_HERE';

  // 2️⃣ REMPLACER PAR VOTRE UPLOAD PRESET
  static const String uploadPreset = 'CLOUDINARY_URL=cloudinary://655972484357624:@dhcpkhuao';
}
```

---

## 🔑 Comment obtenir ces valeurs ?

### 1️⃣ Cloud Name (Obligatoire)

1. Allez sur [https://cloudinary.com/console](https://cloudinary.com/console)
2. Connectez-vous (ou créez un compte gratuit)
3. Sur le Dashboard, copiez votre **"Cloud name"**
   - Exemple : `dq4l3tzyx`
4. Collez-le dans `cloudinary_config.dart` :
   ```dart
   static const String cloudName = 'dq4l3tzyx';  // ← ICI
   ```

### 2️⃣ Upload Preset (Obligatoire)

1. Dans Cloudinary, allez dans **Settings** ⚙️ > **Upload**
2. Section **"Upload presets"** > **"Add upload preset"**
3. **IMPORTANT** : Sélectionnez **"Unsigned"** pour Signing Mode
4. Nommez-le : `trashpicker_preset` (ou autre nom)
5. (Optionnel) Folder : `trash_reports`
6. Cliquez **Save**
7. Collez le nom dans `cloudinary_config.dart` :
   ```dart
   static const String uploadPreset = 'trashpicker_preset';  // ← ICI
   ```

---

## ✅ Exemple de configuration finale

```dart
class CloudinaryConfig {
  static const String cloudName = 'dq4l3tzyx';
  static const String uploadPreset = 'trashpicker_preset';
  static const String uploadFolder = 'trash_reports';  // Ne pas modifier
}
```

---

## 🧪 Tester

```bash
flutter run -d chrome
```

Puis :
1. Connectez-vous en tant que client
2. Activez une demande (toggle ON)
3. Cliquez "Ajouter photos"
4. Sélectionnez une image
5. ✅ Vous devriez voir : "1 photo(s) ajoutée(s) ✓"

---

## ❌ En cas de problème

Si vous voyez "Configuration Cloudinary manquante" :
- Vérifiez que vous avez bien remplacé `YOUR_CLOUD_NAME_HERE` et `YOUR_UPLOAD_PRESET_HERE`
- Relancez l'application

Si l'upload échoue avec erreur 401 :
- Vérifiez que votre Upload Preset est en mode **"Unsigned"**

---

## 📖 Guide complet

Pour plus de détails : [CLOUDINARY_SETUP.md](CLOUDINARY_SETUP.md)

---

**C'est tout !** 🎉 L'upload devrait maintenant fonctionner sur web, Android et iOS.
